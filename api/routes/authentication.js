import Express from 'express';
import wrap from 'express-async-wrap';
import User from '../models/user';
import jwt from 'jwt-simple';
import { key } from '../config/secret';

import { requireAuth, requireSignin } from '../services/passport';

const Router = new Express.Router();

const tokenForUser = (user) => {
  const timeStamp = new Date().getTime();
  return jwt.encode({ sub: user.id, iat: timeStamp }, key);
};



export default [
  Router.post('/signup', wrap(async function(req, res) {
    const email = req.body.email;
    const password = req.body.password;

    if(!email || !password) {
      return res.status(422).send({error: 'You must provide both an email and a password'});
    }

    User.findOne({email: email}, function (err, existingUser) {
      if(err) {return next(err)}

      if(existingUser) {
        return res.status(422).send({error: 'Email in use'});
      }

      const user = new User({
        email,
        password
      });

      user.save(function (err) {
        if(err) {return next(err)}

        return res.json({token: tokenForUser(user)});
      })
    });
  })),
  Router.get('/testArea', requireAuth, function(req, res) {
    res.send({ hi: 'there'});
  }),
  Router.post('/signin', requireSignin, function(req, res){
    res.send({token: tokenForUser(req.user)});
  })
];
