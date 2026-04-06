const CrowdLog = require('../models/CrowdLog');

let espClient = null;

const flutterClients = new Set();

//Broadcast STATUS
const broadcastStatus = () => {
  const payload = JSON.stringify({
    type: "STATUS",
    node: true,
    esp: !!espClient
  });

  flutterClients.forEach(client => {
    if (client.readyState === 1) {
      client.send(payload);
    }
  });
};

setInterval(() => {
  if (espClient) {
    const now = Date.now();

    // If no message from ESP for 5 seconds → consider disconnected
    if (now - espLastSeen > 5000) {
      console.log('[WS] ESP timeout → considered disconnected');

      try {
        espClient.terminate(); // force close
      } catch (e) {}

      espClient = null;
      broadcastStatus();
    }
  }
}, 3000);

//Handle Incoming Message
const handleMessage = async (ws, isFlutter, message) => {
  try {
    const data = JSON.parse(message);

    console.log("Client: ",data);

    // Only ESP sends data
    if (!isFlutter) {
      espLastSeen = Date.now();
      // Save to DB
      const saved = await CrowdLog.create(data);

      // FULL DATA → Flutter
      const fullPayload = JSON.stringify({
        type: "DATA",
        ...data,
        timestamp: new Date().toISOString(),
        id: saved._id
      });

      flutterClients.forEach(client => {
        if (client.readyState === 1) {
          client.send(fullPayload);
        }
      });

      // LIMITED DATA → ESP
      if (espClient && espClient.readyState === 1) {
        espClient.send(JSON.stringify({
          type: "CONTROL",
          count: data.count,
          status: data.status
        }));
      }
    }

  } catch (err) {
    console.error('[WS ERROR]', err.message);
  }
};

//Handle Connection
const handleConnection = (ws, req) => {
  const isFlutter = req.url.includes('flutter');

  if (isFlutter) {
    flutterClients.add(ws);
    console.log(`[WS] Flutter connected (${flutterClients.size})`);
  } else {
    espClient = ws;
    console.log('[WS] ESP32 connected');
  }

  broadcastStatus();

  ws.on('message', (msg) => handleMessage(ws, isFlutter, msg));

  ws.on('close', () => {
    if (ws === espClient) {
      espClient = null;
      console.log('[WS] ESP disconnected');
    }

    if (flutterClients.has(ws)) {
      flutterClients.delete(ws);
      console.log('[WS] Flutter disconnected');
    }

    broadcastStatus();
  });

  ws.on('error', () => {
    if (ws === espClient) espClient = null;
    flutterClients.delete(ws);
  });

  // Send latest data to Flutter
  if (isFlutter) {
    CrowdLog.findOne().sort({ createdAt: -1 }).then(latest => {
      if (latest && ws.readyState === 1) {
        ws.send(JSON.stringify({
          type: "DATA",
          ...latest.toObject()
        }));
      }
    });
  }
};



module.exports = {
  handleConnection
};