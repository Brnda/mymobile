import mongoose from 'mongoose';
const Schema = mongoose.Schema;
import bcrypt from 'bcrypt-nodejs';

const userSchema = new Schema({
  email: {type: String, unique: true},
  password: String
});

userSchema.pre('save', function(next) {
  const user = this;

  bcrypt.genSalt(10, (err, salt) => {
    if(err){ return next(err) }

    bcrypt.hash(user.password, salt, null, (error, hash) => {
      if(error){ return next(error) }

      user.password = hash;
      next();
    });
  });
});

const ModelClass = mongoose.model('user', userSchema);

module.exports = ModelClass;