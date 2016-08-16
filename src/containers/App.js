import {bindActionCreators} from 'redux'
import {connect} from 'react-redux'
import * as authActions from '../reducers/auth/authActions'
import React from 'react'

import {
  StyleSheet,
  View,
  Text,
  TouchableHighlight
} from 'react-native';
const FBSDK = require('react-native-fbsdk');
const {
  LoginButton,
} = FBSDK;


var styles = StyleSheet.create({
  container: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#272727'
  },

  messageBox: {
    backgroundColor: '#1e9e6b',
    width: 300,
    paddingTop: 10,
    paddingBottom: 20,
    paddingLeft: 20,
    paddingRight: 20,
    borderRadius: 7
  },

  messageBoxTitleText: {
    fontFamily: 'Lato-Regular',
    fontSize: 18,
    color: '#fff',
    textAlign: 'center',
    marginBottom: 10
  },
  messageBoxBodyText: {
    color: '#fff',
    fontFamily: 'Lato-Regular',
    textAlign: 'center',
    fontSize: 12
  }
});

/**
 * ## App class
 *
 */
let App = React.createClass({

  render() {
    return (
      <View style={styles.container}>
        <View style={styles.messageBox}>
          <View>
            <Text style={styles.messageBoxTitleText}>Welcome to Owal, {this.props.name}!</Text>
          </View>
          <View>
            <LoginButton
              //publishPermissions={["publish_actions"]}
              onLoginFinished={
                (error, result) => {
                  if (error) {
                    alert("Login failed with error: " + result.error);
                  } else if (result.isCancelled) {
                    alert("Login was cancelled");
                  } else {
                    alert("Login was successful with permissions: " + result.grantedPermissions)
                  }
                }
              }
              onLogoutFinished={() => alert("User logged out")}/>
          </View>
        </View>
      </View>
    )
  }
})

function mapStateToProps(state) {
  console.log(`State is ${JSON.stringify(state)}`)
  return {
    name: state.auth.getIn(['user', 'username'])
  }
}

function mapDispatchToProps(dispatch) {
  return {
    actions: bindActionCreators({...authActions}, dispatch),
    dispatch
  }
}

export default connect(mapStateToProps, mapDispatchToProps)(App);
