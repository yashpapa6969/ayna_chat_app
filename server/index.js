const express = require("express");
const cors = require("cors");
const mongoose = require("mongoose");
const authRoutes = require("./routes/auth");
const messageRoutes = require("./routes/messages");
const app = express();
const socket = require("socket.io");
const ConnectToDb = require("./connect");

require("dotenv").config();

app.use(cors());
app.use(express.json());

ConnectToDb();
app.use("/api/auth", authRoutes);
app.use("/api/messages", messageRoutes);

const server = app.listen(process.env.PORT || 3000, () =>
  console.log(`Server started on ${process.env.PORT || 3000}`)
);

const io = socket(server, {
  cors: {
    origin: "https://poor-frogs-worry.loca.lt",
    credentials: true,
  },
});

global.onlineUsers = new Map();
io.on("connection", (socket) => {
  console.log("User connected", socket.id);

  socket.on("add-user", (userId) => {
    onlineUsers.set(userId, socket.id);
    console.log(`User ${userId} added with socket ${socket.id}`);
  });

  socket.on("send-msg", (data) => {
    const sendUserSocket = onlineUsers.get(data.to);
    if (sendUserSocket) {
      socket.to(sendUserSocket).emit("msg-recieve", { msg: data.msg, from: data.from });
      console.log(`Message sent from ${data.from} to ${data.to}: ${data.msg}`);
    } else {
      console.log("User not found or not online");
    }
  });

  socket.on("disconnect", () => {
    console.log("User disconnected", socket.id);
    onlineUsers.forEach((value, key) => {
      if (value === socket.id) {
        onlineUsers.delete(key);
        console.log(`User ${key} removed`);
      }
    });
  });
});

