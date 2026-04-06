const { WebSocketServer } = require('ws');
const { handleConnection } = require('../controllers/wsController');

const initWebSocket = (server) => {
  const wss = new WebSocketServer({ server });

  wss.on('connection', handleConnection);

  console.log('[WS] WebSocket server initialized');
};

module.exports = initWebSocket;