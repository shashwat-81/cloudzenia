const http = require('http');

const hostname = '0.0.0.0';
const port = process.env.PORT || 3000;

const server = http.createServer((req, res) => {
  // Health check endpoint
  if (req.url === '/health') {
    res.statusCode = 200;
    res.setHeader('Content-Type', 'application/json');
    res.end(JSON.stringify({ status: 'healthy', timestamp: new Date().toISOString() }));
    return;
  }

  // Main endpoint
  if (req.url === '/') {
    res.statusCode = 200;
    res.setHeader('Content-Type', 'text/plain');
    res.end('Hello from Microservice');
    return;
  }

  // JSON endpoint for API
  if (req.url === '/api/message') {
    res.statusCode = 200;
    res.setHeader('Content-Type', 'application/json');
    res.end(JSON.stringify({ 
      message: 'Hello from Microservice',
      timestamp: new Date().toISOString(),
      service: 'CloudZenia Microservice'
    }));
    return;
  }

  // 404 for unknown routes
  res.statusCode = 404;
  res.setHeader('Content-Type', 'text/plain');
  res.end('Not Found');
});

server.listen(port, hostname, () => {
  console.log(`Microservice running at http://${hostname}:${port}/`);
  console.log('Health check: http://localhost:3000/health');
  console.log('Main endpoint: http://localhost:3000/');
  console.log('API endpoint: http://localhost:3000/api/message');
});

server.on('error', (err) => {
  console.error('Server error:', err);
  process.exit(1);
});

process.on('SIGTERM', () => {
  console.log('SIGTERM signal received: closing HTTP server');
  server.close(() => {
    console.log('HTTP server closed');
    process.exit(0);
  });
});
