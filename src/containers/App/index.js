import {bindActionCreators} from 'redux';
import {connect} from 'react-redux';
import * as authActions from '../../reducers/auth/authActions';
import React, {Component} from 'react';
import {Actions} from 'react-native-router-flux';
import styles from './styles';

import {
    StyleSheet,
    View,
    Text,
    TouchableHighlight,
    Image
} from 'react-native';

/**
 * ## App class
 *
 */
class App extends Component {
  _onPressOut() {
    Actions.qrcodescreen({onSuccess: App._onSuccess});
  }

  static _onSuccess(result) {
    console.log('I got this far '+ result);
  }

  render() {
    return (
        <View style={styles.container}>
          <View>
            <Image
                source={{uri: 'http://owal.io/wp-content/uploads/2016/04/Screen-Shot-2016-04-17-at-7.22.29-PM.png'}}
                style={styles.logo}/>
          </View>
          <View style={styles.messageBoxContainer}>
            <View style={styles.messageBox}>
              <Text style={styles.messageBoxBodyText}>Welcome to OWAL. Enter an invite code or scan a QR code.</Text>
            </View>
          </View>
          <View style={styles.choiceBoxes}>
            <TouchableHighlight onPress={this._onPressOut} style={styles.touchable}>
              <View style={styles.choiceBox}>
                <Text>QR Code</Text>
              </View>
            </TouchableHighlight>
            <View style={styles.choiceBox}>
              <Text>Invite Code</Text>
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
