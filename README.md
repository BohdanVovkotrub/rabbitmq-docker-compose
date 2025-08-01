# RabbitMQ example setup for Docker-Compose

This is an example setup for RabbitMQ with Docker Compose.

## How to use it

Firstly, you need to create `.env` file based on `.env.example`

You can copy `.env.example` to `.env` but I recomment to change login and password to your.

On Windows 10/11 run `run-rabbitmq.cmd`

To stop run `stop-rabbitmq.cmd`

To manage go to `http://<your-local-address>:15672`

To connect from your apps use address `http://<your-local-address>:5672`



## Example to use it in NodeJS


- `RabbitMQ.js` - this is the main script for connecting to rabbitmq

```JS
// `core/RabbitMQ.js`

const amqp = require('amqplib');


class RabbitMQ {
  connection;

  constructor({ host, username, password, reconnectTimeout }) {
    this.host = host;
    this.credentials = amqp.credentials.plain(username, password);
    this.reconnectTimeout = reconnectTimeout;
    this.plannedReconnection = undefined;
  };

  connect = async () => {
    return new Promise(async (resolve, reject) => {
      try {
        if (typeof this.plannedReconnection !== 'undefined') clearTimeout(this.plannedReconnection);
        this.connection = await amqp.connect(this.host, { credentials: this.credentials });
        const { cluster_name } = this.connection.connection.serverProperties;
        const { address, port } = this.connection.connection.stream.address();
        console.log(`Connected to RabbitMQ <${cluster_name}> as <${address}:${port}>`);
        this.connection.on('close', this.connect);
        resolve(this.connection);
      } catch (error) {
        console.error(`Error while <connect> in <RabbitMQ>: ${error.message}`);
        console.log(`Try to reconnect on ${this.reconnectTimeout} seconds.`);
        await new Promise((res) => setTimeout(async () => {
          await this.connect();
          res();
        }, this.reconnectTimeout * 1000));
        resolve(this.connection)
      };
    });
  };
};


module.exports = RabbitMQ;
```

- `producer.js` — sends messages to the queue

```JS
// example/producer.js
const RabbitMQ = require('../core/RabbitMQ.js');

const config = {
  host: 'amqp://localhost',
  username: 'guest',
  password: 'guest',
  reconnectTimeout: 5, // seconds
  queue: 'tasks',
};

(async () => {
  const rabbit = new RabbitMQ({
    host: config.host,
    username: config.username,
    password: config.password,
    reconnectTimeout: config.reconnectTimeout,
  });

  await rabbit.connect();

  const channel = await rabbit.connection.createChannel();

  // Ensure the queue exists
  await channel.assertQueue(config.queue, { durable: true });

  const message = { taskId: Date.now(), payload: 'Hello from producer!' };
  channel.sendToQueue(config.queue, Buffer.from(JSON.stringify(message)), {
    persistent: true,
  });

  console.log('Message sent:', message);
  setTimeout(() => process.exit(0), 500); // завершити процес
})();

```


- `consumer.js` — receives messages from the queue

```JS
// example/consumer.js

const RabbitMQ = require('../core/RabbitMQ.js');

const config = {
  host: 'amqp://localhost',
  username: 'guest',
  password: 'guest',
  reconnectTimeout: 5, // seconds
  queue: 'tasks',
};

(async () => {
  const rabbit = new RabbitMQ({
    host: config.host,
    username: config.username,
    password: config.password,
    reconnectTimeout: config.reconnectTimeout,
  });

  await rabbit.connect();

  const channel = await rabbit.connection.createChannel();

  // Create or ensure the queue exists
  await channel.assertQueue(config.queue, { durable: true });

  console.log(`Waiting for messages in queue <${config.queue}>...`);

  channel.consume(
    config.queue,
    (msg) => {
      if (msg !== null) {
        const content = msg.content.toString();
        console.log(`Received: ${content}`);

        // Acknowledge the message
        channel.ack(msg);
      }
    },
    { noAck: false }
  );
})();

```
