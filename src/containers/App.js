/**
 * # app.js
 *  Display startup screen and
 *  getSessionTokenAtStartup which will navigate upon completion
 *
 *
 *
 */
'use strict';
import {bindActionCreators} from 'redux';
import {connect} from 'react-redux';
import {Map} from 'immutable';
import * as authActions from '../reducers/auth/authActions';
import * as deviceActions from '../reducers/device/deviceActions';
import * as globalActions from '../reducers/global/globalActions';
import React, {
  StyleSheet,
  View,
  Text,
  TouchableHighlight
} from 'react-native';

/**
 * ## Actions
 * 3 of our actions will be available as ```actions```
 */
const actions = [
  authActions,
  deviceActions,
  globalActions
];

/**
 *  Save that state
 */
function mapStateToProps(state) {
  return {
    ...state
  };
};

/**
 * Bind all the functions from the ```actions``` and bind them with
 * ```dispatch```
 */
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
  /**
   * See if there's a sessionToken from a previous login
   *
   */
  componentDidMount() {
    this.props.actions.getSessionToken();
  },

  _onPressButton() {
    console.log(`Logged in screen view!`);
  },

  render() {
    return (
      <View style={styles.container}>
        <View style={styles.messageBox}>
          <View>
            <Text style={styles.messageBoxTitleText}>Welcome to Owal!</Text>
          </View>
          <View>
            <TouchableHighlight onPress={this._onPressButton}>
              <Text style={styles.messageBoxBodyText}>Login using FB.</Text>
            </TouchableHighlight>
          </View>
        </View>
      </View>
    );
  }
});

/**
 * Connect the properties
 */
export default connect(mapStateToProps, mapDispatchToProps)(App);

