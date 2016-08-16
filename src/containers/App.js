import {bindActionCreators} from 'redux';
import {connect} from 'react-redux';
import * as authActions from '../reducers/auth/authActions';
import React, {Component} from 'react';
import Button from 'react-native-button';
import {Actions} from 'react-native-router-flux';

import {
  StyleSheet,
  View,
  Text,
  TouchableHighlight
} from 'react-native';


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
class App extends Component {
  onEmailSignup(event) {

  }

  render() {
    return (
      <View style={styles.container}>
        <View style={styles.messageBox}>
          <View>
            <Button onPress={Actions.fbsignup}>Signup with an Facebook</Button>
          </View>
          <View>
            <Button onPress={Actions.googsignup}>Signup with an Google</Button>
          </View>
          <View>
            <Button onPress={Actions.emailsignup}>Signup with an email</Button>
          </View>
        </View>
      </View>
    )
  }
}

function mapStateToProps(state) {
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
