const mongoose = require('mongoose');
const Schema = mongoose.Schema;

const userSchema = new Schema({
  email: {type: String, unique: true},
  password: String
});

const ModelClass = mongoose.model('user', userSchema);

module.exports = ModelClass;