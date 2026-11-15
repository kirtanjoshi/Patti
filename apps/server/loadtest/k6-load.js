import ws from 'k6/ws';
import { check, sleep } from 'k6';

/**
 * k6 load test simulating concurrent WebSocket connections to Patii game server
 * Target: 5,000 concurrent connections with ping/pong and table heartbeats
 */
export const options = {
  stages: [
    { duration: '30s', target: 500 },    // Ramp up to 500 users
    { duration: '1m', target: 2000 },    // Ramp up to 2,000 users
    { duration: '2m', target: 5000 },    // Peak at 5,000 users
    { duration: '1m', target: 5000 },    // Stay at 5,000 users
    { duration: '30s', target: 0 },      // Ramp down
  ],
  thresholds: {
    ws_connecting: ['p(95)<150'], // Connection p95 < 150ms
    checks: ['rate>0.99'],        // 99% success rate
  },
};

export default function () {
  const serverUrl = __ENV.SERVER_URL || 'ws://localhost:3001/socket.io/?EIO=4&transport=websocket';
  const userId = `load_user_${__VU}_${__ITER}`;

  const res = ws.connect(serverUrl, {}, function (socket) {
    socket.on('open', () => {
      // 1. Initial Socket.IO handshake packet
      socket.send('40/game,');

      // 2. Queue for Callbreak quick match
      socket.send(
        '42/game,["queue:join",{"gameId":"CALLBREAK","tier":"bronze","userId":"' +
          userId +
          '"}]',
      );
    });

    socket.on('message', (data) => {
      // Respond to Engine.IO ping
      if (data === '2') {
        socket.send('3'); // pong
      }
    });

    socket.on('close', () => {
      // Connection closed
    });

    // Keep session active with periodic ping every 10 seconds
    socket.setInterval(function () {
      socket.send('2');
    }, 10000);

    // Stay connected for 30s
    sleep(30);
    socket.close();
  });

  check(res, { 'status is 101 Switching Protocols': (r) => r && r.status === 101 });
}
