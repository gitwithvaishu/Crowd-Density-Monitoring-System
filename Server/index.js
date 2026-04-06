require('dotenv').config();
const express = require('express');
const cors = require('cors');
const http = require('http');

const connectDB = require('./config/db');
const crowdRoutes = require('./routes/crowdRoutes');
const initWebSocket = require('./websocket/wsServer');

const app = express();
const server = http.createServer(app);

//Middleware
app.use(cors());
app.use(express.json());

//Routes
app.use('/api/crowd', crowdRoutes);

//DB Connect
connectDB();

//WebSocket Init
initWebSocket(server);

//Start Server
const PORT = process.env.PORT || 3000;

server.listen(PORT, () => {
  console.log(`[Server] Running on port ${PORT}`);
});



// const express = require('express');
// const mongoose = require('mongoose');
// const cors = require('cors');
// const ws= require('ws');
// const http = require('http');
// require('dotenv').config();

// const app = express();
// app.use(cors());
// app.use(express.json());

// // ── MongoDB ─────────────────────────
// mongoose.connect(process.env.MONGO_URI)
//   .then(() => console.log('[DB] Connected'))
//   .catch(err => console.error('[DB ERROR]', err));

// // ── Schema ─────────────────────────
// const CrowdLog = mongoose.model('CrowdLog', new mongoose.Schema({
//   event: String,
//   count: Number,
//   density: Number,
//   status: String,
//   maxCapacity: Number
// }, { timestamps: true }));

// const PORT = process.env.PORT || 3000;

// const server = server.listen(PORT, () => {
//   console.log('[Server] Running on port 3000');
// });
// const wss = new WebSocket.Server({ server });

// //Clients
// let espClient = null;
// const flutterClients = new Set();

// //Broadcast STATUS
// function broadcastStatus() {
//   const payload = JSON.stringify({
//     type: "STATUS",
//     node: true,
//     esp: !!espClient
//   });

//   flutterClients.forEach(client => {
//     if (client.readyState === 1) {
//       client.send(payload);
//     }
//   });
// }

// //WebSocket Server
// wss.on('connection', (ws, req) => {
//   const isFlutter = req.url.includes('flutter');

//   if (isFlutter) {
//     flutterClients.add(ws);
//     console.log(`[WS] Flutter connected | total: ${flutterClients.size}`);
//   } else {
//     espClient = ws;
//     console.log('[WS] ESP32 connected');
//   }

//   // Send current status immediately
//   broadcastStatus();

//   ws.on('message', async (msg) => {
//     try {
//       const data = JSON.parse(msg);

//       // Only ESP sends DATA
//       if (!isFlutter) {
//         await CrowdLog.create(data);

//         console.log(data);

//         //Send DATA → ESP
//         if (espClient && espClient.readyState === 1) {
//           espClient.send(JSON.stringify({
//             type: "CONTROL",
//             count: data.count,
//             status: data.status
//           }));
//         }

//         //Send DATA → Flutter
//         const fullPayload = JSON.stringify({
//           type: "DATA",
//           ...data,
//           timestamp: new Date().toISOString()
//         });

//         flutterClients.forEach(client => {
//           if (client.readyState === 1) {
//             client.send(fullPayload);
//           }
//         });

        
//       }

//     } catch (err) {
//       console.error('[WS ERROR]', err.message);
//     }
//   });

//   ws.on('close', () => {
//     if (ws === espClient) {
//       espClient = null;
//       console.log('[WS] ESP disconnected');
//     }

//     if (flutterClients.has(ws)) {
//       flutterClients.delete(ws);
//       console.log('[WS] Flutter disconnected');
//     }

//     broadcastStatus();
//   });

//   ws.on('error', () => {
//     if (ws === espClient) espClient = null;
//     flutterClients.delete(ws);
//   });
// });








// require('dotenv').config();
// const express   = require('express');
// const mongoose  = require('mongoose');
// const cors      = require('cors');
// const { WebSocketServer } = require('ws');
// const http      = require('http');
// const CrowdLog  = require('./models/CrowdLog');
// const crowdRoutes = require('./routes/crowd');

// const app    = express();
// const server = http.createServer(app);
// const wss    = new WebSocketServer({ server });

// app.use(cors());
// app.use(express.json());
// app.use('/api/crowd', crowdRoutes);

// // ── MongoDB Connect ────────────────────────────
// mongoose.connect(process.env.MONGO_URI)
//   .then(() => console.log('[DB] MongoDB connected'))
//   .catch(err => console.error('[DB] Error:', err));

// // ── Track all WebSocket clients ────────────────
// const clients = new Set();

// // ── WebSocket Server ───────────────────────────
// wss.on('connection', (ws, req) => {
//   const clientType = req.url.includes('flutter') ? 'FLUTTER' : 'ESP32';
//   console.log(`[WS] ${clientType} client connected`);
//   clients.add(ws);

//   ws.on('message', async (data) => {
//     try {
//       const parsed = JSON.parse(data);
//       console.log('[WS] Received:', parsed);

//       // Save to MongoDB
//       const log = new CrowdLog({
//         event:       parsed.event,
//         count:       parsed.count,
//         density:     parsed.density,
//         status:      parsed.status,
//         maxCapacity: parsed.maxCapacity
//       });
//       await log.save();

//       // Broadcast to ALL clients (including Flutter app)
//       const broadcastData = JSON.stringify({
//         ...parsed,
//         timestamp: new Date().toISOString(),
//         savedId: log._id
//       });

//       clients.forEach(client => {
//         if (client.readyState === 1) { // OPEN
//           client.send(broadcastData);
//         }
//       });

//     } catch (err) {
//       console.error('[WS] Parse error:', err.message);
//     }
//   });

//   ws.on('close', () => {
//     clients.delete(ws);
//     console.log('[WS] Client disconnected');
//   });

//   // Send latest data to newly connected Flutter client
//   CrowdLog.findOne().sort({ timestamp: -1 }).then(latest => {
//     if (latest && ws.readyState === 1) {
//       ws.send(JSON.stringify(latest));
//     }
//   });
// });

// const PORT = process.env.PORT || 3000;
// server.listen(PORT, () => {
//   console.log(`[Server] Running on port ${PORT}`);
// });