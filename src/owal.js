import React, {Component} from 'react';
import {
    AppRegistry,
    Navigator,
    View,
    AsyncStorage,
    Text,
    TouchableHighlight
} from 'react-native';
import {
    Router,
    Scene,
    ActionConst,
} from 'react-native-router-flux';
import {Provider} from 'react-redux';
import configureStore from './lib/configureStore';
import Induction from './containers/Induction/index';
import TenantReview from './containers/TenantReview';
import QRCodeScreen from './components/QRCodeScreen';
import Enjoy from './components/Enjoy';
import InitialScreen from './components/InitialScreen';
import Home from './containers/Home';
import TenantReviewDirectory from './containers/TenantReviewDirectory';
import TextInviteCodeScreen from './containers/TextInviteCodeScreen';
import MyFloorView from './containers/MyFloorView';
import TabIconBuilding from './components/TabIconBuilding';
import TabIconMessage from './components/TabIconMessage';
import TabIconProfile from './components/TabIconProfile';
import ChatScreen from './components/ChatScreen';
import UserProfile from './containers/UserProfile';
import FCM from 'react-native-fcm';

export default function native(platform) {

  class Owal extends Component {
    componentDidMount() {
      FCM.requestPermissions(); // for iOS
      FCM.getFCMToken().then(token => {
        console.log(token)
        // store fcm token in your server
      });
      this.notificationUnsubscribe = FCM.on('notification', (notif) => {
        // there are two parts of notif. notif.notification contains the notification payload, notif.data contains data payload
        if(notif.local_notification){
          //this is a local notification
        }
        if(notif.opened_from_tray){
          //app is open/resumed because user clicked banner
        }
      });
      this.refreshUnsubscribe = FCM.on('refreshToken', (token) => {
        console.log(token)
        // fcm token may not be available on first load, catch it here
      });
    }

    render() {
      const store = configureStore();
      // setup the router table with Induction selected as the initial component
      return (
          <Provider store={store}>
            <Router hideNavBar={true}>
              <Scene key="root">
                <Scene key="initial" component={InitialScreen} initial/>
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
                <Scene key="main" tabs={true} style={{backgroundColor: '#262626'}}>
                  <Scene key="home" component={Home} title="Tab #1" icon={TabIconBuilding} />
                  <Scene key="message" component={ChatScreen} title="Message" icon={TabIconMessage} />
                  <Scene key="profile" component={UserProfile} title="Profile" icon={TabIconProfile} />
                </Scene>
                <Scene key="enjoy"
                       component={Enjoy}/>
                <Scene key="viewVideo"
                       component={MyFloorView}/>
              </Scene>
            </Router>
          </Provider>
      )
    }
  };

  AppRegistry.registerComponent('owalMobile', () => Owal)
}