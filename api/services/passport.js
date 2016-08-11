import passport from 'passport';
import User from '../models/user';
import { key } from '../config/secret';
import LocalStrategy from 'passport-local';

import { Strategy, ExtractJwt } from 'passport-jwt';

const localOptions = {usernameField: 'email'};
const localLogin = new LocalStrategy(localOptions, function(email, password, done){
  User.findOne({email: email}, (err, user) => {
    if(err) { return done(err) }

    if(!user) { return done(null, false) }

    user.comparePassword(password, (err, isMatch) => {
      if(err) { return done(err)}

      if(!isMatch) { return done(null, false); }

      return done(null, user);
    });
  });
});

const jwtOptions = {
  jwtFromRequest: ExtractJwt.fromHeader('authorization'),
  secretOrKey: key
};

const jwtLogin = new Strategy(jwtOptions, (payload, done) => {
  User.findById(payload.sub, (err, user) => {
      if(err){ return done(err, false)}

      if(user){
        done(null, user);
      }else{
        done(null, false);
      }
  });
});

passport.use(jwtLogin);
passport.use(localLogin);

export const requireAuth = passport.authenticate('jwt', { session: false });
export const requireSignin = passport.authenticate('local', { session: false });


