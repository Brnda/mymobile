import React, { Component } from 'react';
import FBSDK from 'react-native-fbsdk';

const {
  LoginButton,
} = FBSDK;

class FacebookLogin extends Component {
  render() {
    return <LoginButton
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
  }
}