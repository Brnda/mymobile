'use strict';

import React, {
  AppRegistry,
  Navigator,
  View,
  Text
} from 'react-native';
import RNRF, {
  Route,
  Scene,
  TabBar
} from 'react-native-router-flux';
import {
  Provider,
  connect
} from 'react-redux';
import configureStore from './lib/configureStore';
import App from './containers/App';
import Login from './containers/Login';
import Logout from './containers/Logout';
import Register from './containers/Register';
import ForgotPassword from './containers/ForgotPassword';
import Profile from './containers/Profile';
import Main from './containers/Main';
import Subview from './containers/Subview';
import Icon from 'react-native-vector-icons/FontAwesome';
import {setPlatform, setVersion} from './reducers/device/deviceActions';
import {setStore} from './reducers/global/globalActions';
import authInitialState from './reducers/auth/authInitialState';
import deviceInitialState from './reducers/device/deviceInitialState';
import globalInitialState from './reducers/global/globalInitialState';
import profileInitialState from './reducers/profile/profileInitialState';

/**
 *  The version of the app but not  displayed yet
 */
var VERSION = '0.1.1';

/**
 *
 * ## Initial state
 * Create instances for the keys of each structure
 * @returns {Object} object with 4 keys
 */
function getInitialState() {
  const _initState = {
    auth: new authInitialState,
    device: (new deviceInitialState).set('isMobile', true),
    global: (new globalInitialState),
    profile: new profileInitialState
  };
  return _initState;
}
/**
 * ## TabIcon
 *
 * Displays the icon for the tab w/ color dependent upon selection
 */

class TabIcon extends React.Component {
  render() {
    var color = this.props.selected ? '#FF3366' : '#FFB3B3';
    return (
      <View style={{flex:1, flexDirection:'column', alignItems:'center', alignSelf:'center'}}>
        <Icon style={{color: color}} name={this.props.iconName} size={30}/>
        <Text style={{color: color}}>{this.props.title}</Text>
      </View>
    );
  }
}

/**
 * ## Native
 *
 * ```configureStore``` with the ```initialState``` and set the
 * ```platform``` and ```version``` into the store by ```dispatch```.
 * *Note* the ```store``` itself is set into the ```store```.  This
 * will be used when doing hot loading
 */

export default function native(platform) {

  let Owal = React.createClass({
    render() {

      const store = configureStore(getInitialState());

      //Connect w/ the Router
      const Router = connect()(RNRF.Router);

      store.dispatch(setPlatform(platform));
      store.dispatch(setVersion(VERSION));
      store.dispatch(setStore(store));

      // setup the router table with App selected as the initial component
      return (
        <Provider store={store}>
          <Router hideNavBar={true}>
            <Scene key="root">
              <Scene key="App"
                     component={App}
                     title="App"
                     initial={true}/>


            </Scene>
          </Router>
        </Provider>
      );
    }
  });
  /**
   * registerComponent to the AppRegistery and off we go....
   */

  AppRegistry.registerComponent('owal', () => Owal);
}
