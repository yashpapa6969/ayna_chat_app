const User = require("../models/userModel");
const bcrypt = require("bcrypt");

module.exports.login = async (req, res, next) => {
  try {
    const { username, password } = req.body;
    const user = await User.findOne({ username });
    if (!user) {
      // Sending a 401 status when the username is not found or password is invalid.
      return res.status(401).json({ msg: "Incorrect Username or Password", status: false });
    }
    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      // Sending a 401 status when the password is invalid.
      return res.status(401).json({ msg: "Incorrect Username or Password", status: false });
    }
    // Removing sensitive data before sending the user data.
    user.password = undefined; // Prefer setting to undefined over delete for performance reasons.
    // Sending a 200 status with the user data when login is successful.
    return res.status(200).json({ status: true, user });
  } catch (ex) {
    // Passing errors to the error-handling middleware.
    next(ex);
  }
};

module.exports.register = async (req, res, next) => {
  try {
    const { username, email, password } = req.body;
    
    // Check if the username is already in use
    const usernameCheck = await User.findOne({ username });
    if (usernameCheck) {
      return res.status(409).json({ msg: "Username already used", status: false });
    }
    
    // Check if the email is already in use
    const emailCheck = await User.findOne({ email });
    if (emailCheck) {
      return res.status(409).json({ msg: "Email already used", status: false });
    }

    // Check if the password was provided
    if (!password) {
      return res.status(400).json({ msg: "Password is required", status: false });
    }

    // Hash the password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create the user
    const user = await User.create({
      email,
      username,
      password: hashedPassword,
    });

    // Removing sensitive data before sending the user data

    // Sending a 201 status for successful resource creation
    return res.status(201).json({ status: true, user });
  } catch (ex) {
    // Passing errors to the error-handling middleware
    next(ex);
  }
};


module.exports.getAllUsers = async (req, res, next) => {
  try {
    const users = await User.find({ _id: { $ne: req.params.id } }).select([
      "email",
      "username",
      "avatarImage",
      "_id",
    ]);
    return res.json(users);
  } catch (ex) {
    next(ex);
  }
};

module.exports.setAvatar = async (req, res, next) => {
  try {
    const userId = req.params.id;
    const avatarImage = req.body.image;
    const userData = await User.findByIdAndUpdate(
      userId,
      {
        isAvatarImageSet: true,
        avatarImage,
      },
      { new: true }
    );
    return res.json({
      isSet: userData.isAvatarImageSet,
      image: userData.avatarImage,
    });
  } catch (ex) {
    next(ex);
  }
};

module.exports.logOut = (req, res, next) => {
  try {
    if (!req.params.id) return res.json({ msg: "User id is required " });
    onlineUsers.delete(req.params.id);
    return res.status(200).send();
  } catch (ex) {
    next(ex);
  }
};
