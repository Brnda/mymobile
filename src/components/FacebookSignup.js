import React, {Component} from 'react';
import FBSDK from 'react-native-fbsdk';
import {View, Text, StyleSheet} from 'react-native';
import Button from 'react-native-button';
import {Actions} from 'react-native-router-flux';

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
  }
});

export default class FacebookSignup extends Component {
  render() {
    return <View style={styles.container}>
      <View>
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
        <View>
          <Button onPress={()=>Actions.home({name: 'Mateo'})}>Next</Button>
        </View>
      </View>
    </View>
  }
}