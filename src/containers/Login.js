/**
 * # Login.js
 * 
 *  The container to display the Login form 
 * 
 */
'use strict';
/**
 * ## Imports
 * 
 * Redux 
 */
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';

/**
 * The actions we need
 */
import * as authActions from '../reducers/auth/authActions';

/**
 * Immutable
 */ 
import {Map} from 'immutable';

/**
 *   LoginRender
 */
import LoginRender from '../components/LoginRender';

/**
 * The necessary React components
 */
import React from 'react-native';


const {
  LOGIN,
  REGISTER, 
  FORGOT_PASSWORD 
} = require('../lib/constants').default;

/**
 * ## Redux boilerplate
 */
const actions = [
  authActions
];

function mapStateToProps(state) {
  return {
      ...state
  };
}

function mapDispatchToProps(dispatch) {
  const creators = Map()
          .merge(...actions)
          .filter(value => typeof value === 'function')
          .toObject();

  return {
    actions: bindActionCreators(creators, dispatch),
    dispatch
  };
}

function buttonPressHandler(login, username, password) {
  login (username, password);
}

let Login = React.createClass({

  render() {
    let loginButtonText = 'Log in';
    let onButtonPress = buttonPressHandler.bind(null,
				                this.props.actions.login,
				                this.props.auth.form.fields.username, 
				                this.props.auth.form.fields.password
		                               );

    return(
      <LoginRender 
          formType={ LOGIN }
          loginButtonText={ loginButtonText }
          onButtonPress={ onButtonPress }
          displayPasswordCheckbox={ true }
          leftMessageType={ REGISTER }
          rightMessageType={ FORGOT_PASSWORD }
          auth={ this.props.auth }
          global={ this.props.global }
      />
    );
  }
});

export default connect(mapStateToProps, mapDispatchToProps)(Login);
