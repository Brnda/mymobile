import Express from 'express';
import wrap from 'express-async-wrap';
import User from '../models/user';

const Router = new Express.Router();

export default [

  Router.post('/signup', wrap(async function(req, res) {
    const email = req.body.email;
    const password = req.body.password;
    console.log(`Got ${email} and ${password}`);
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

        return res.json(user);
      })
    });
  })),
];
