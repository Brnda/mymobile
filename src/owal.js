import React, {
  AppRegistry,
  Navigator,
  View,
  Text
} from 'react-native'
import RNRF, {
  Route,
  Scene
} from 'react-native-router-flux'
import {
  Provider,
  connect
} from 'react-redux'
import configureStore from './lib/configureStore'
import App from './containers/App'
import Home from './containers/Home'

/**
 *
 * ## Initial state
 * @returns {Object} object with 4 keys
 */
function getInitialState() {
  return {};
}

/**
 * ## Native entry point.
 */

export default function native(platform) {

  let Owal = React.createClass({
    render() {

      const store = configureStore(getInitialState());

      //Connect w/ the Router
      const Router = connect()(RNRF.Router);

      // setup the router table with App selected as the initial component
      return (
        <Provider store={store}>
          <Router hideNavBar={true}>
            <Scene key="root">
              <Scene key="app"
                     component={App}
                     title="App"
                     initial={true}/>

              <Scene key="home" 
                     component={Home}/>
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
