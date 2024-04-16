const mongoose = require('mongoose');
const dotenv = require('dotenv');
require("dotenv").config();

function ConnectToDb() {
  const url = process.env.MONGO_URL;

  // Log the connection string to verify it's correct (remove this in production)
  console.log(`Connecting to MongoDB at: ${url}`);

  mongoose.set("strictQuery", true);
  mongoose
    .connect(url)
    .then(() => {
      console.log("Connected to the database");
    })
    .catch((err) => {
      console.error(`Error connecting to the database: ${err}`);
    });

  // Connection Events
  mongoose.connection.on('connected', () => {
    console.log('Mongoose connected to db');
  });

  mongoose.connection.on('error', (err) => {
    console.log(err.message);
  });

  mongoose.connection.on('disconnected', () => {
    console.log('Mongoose connection is disconnected');
  });

  process.on('SIGINT', () => {
    mongoose.connection.close(() => {
      console.log('Mongoose connection is disconnected due to app termination');
      process.exit(0);
    });
  });
}

module.exports = ConnectToDb;
