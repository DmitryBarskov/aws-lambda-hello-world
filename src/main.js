module.exports.handler = async (_event) => ({
  statusCode: 200,
  headers: {
    'Content-Type': 'text/plain',
  },
  body: 'Hello, World!',
});
