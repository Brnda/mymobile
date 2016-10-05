import React, {Component} from 'react';
import {
    AppRegistry,
    Navigator,
    View,
    AsyncStorage,
    Text
} from 'react-native';
import {
    Router,
    Scene,
    ActionConst
} from 'react-native-router-flux';
import {Provider} from 'react-redux';
import configureStore from './lib/configureStore';
import Induction from './containers/App/index';
import TenantReview from './containers/TenantReview';
import QRCodeScreen from './components/QRCodeScreen';
import Enjoy from './components/Enjoy';
import Home from './containers/Home';
import TenantReviewDirectory from './containers/TenantReviewDirectory';
import TextInviteCodeScreen from './containers/TextInviteCodeScreen';
import {STORAGE_KEY} from './lib/constants';
import {Actions} from 'react-native-router-flux';

export default function native(platform) {

  class Owal extends Component {
    componentDidMount() {
      this._loadInitialState().done();
    }

    _loadInitialState = async () => {
      try {
        var value = await AsyncStorage.getItem(STORAGE_KEY);
        if (value == null  || value !== "true") {
          Actions.app();
        } else {
          Actions.home();
        }
      } catch (error) {
        console.error(`Could not use Persistance store.`);
      }
    };

    render() {
      const store = configureStore();
      // setup the router table with App selected as the initial component
      return (
          <Provider store={store}>
            <Router hideNavBar={true}>
              <Scene key="root">
                <Scene key="app"
                       type={ActionConst.REPLACE}
                       component={Induction}/>
                <Scene key="tenatReview"
                       component={TenantReview}/>
                <Scene key="lastTenantQuestion"
                       component={TenantReviewDirectory}/>
                <Scene key="qrcodescreen"
                       component={QRCodeScreen}/>
                <Scene key="textinvitecodescreen"
                       component={TextInviteCodeScreen}/>
                <Scene key="home"
                       type={ActionConst.REPLACE}
                       component={Home}/>
                <Scene key="enjoy"
                       component={Enjoy}/>
              </Scene>
            </Router>
          </Provider>
      )
    }
  };

  AppRegistry.registerComponent('owalMobile', () => Owal)
}
