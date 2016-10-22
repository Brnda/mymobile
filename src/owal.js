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
import Induction from './containers/Induction/index';
import TenantReview from './containers/TenantReview';
import QRCodeScreen from './components/QRCodeScreen';
import Enjoy from './components/Enjoy';
import Home from './containers/Home';
import TenantReviewDirectory from './containers/TenantReviewDirectory';
import TextInviteCodeScreen from './containers/TextInviteCodeScreen';
import {SKIP_INDUCTION_KEY, USER_TOKEN} from './lib/constants';
import {Actions} from 'react-native-router-flux';
import ViewVideo from './containers/ViewVideo';
import MyFloorView from './containers/MyFloorView';
import TabIconBuilding from './components/TabIconBuilding';
import TabIconMessage from './components/TabIconMessage';
import TabIconProfile from './components/TabIconProfile';

export default function native(platform) {

  class Owal extends Component {
    componentDidMount() {
      this._loadInitialState().done();
    }

    _loadInitialState = async () => {
      try {

        const value = await AsyncStorage.getItem(SKIP_INDUCTION_KEY);
        if (value == null  || value !== "true") {
          Actions.app();
        } else {
          const token = await AsyncStorage.getItem(USER_TOKEN);
          Actions.main({token});
        }
      } catch (error) {
        console.error(`Could not use Persistance store.`);
      }
    };

    render() {
      const store = configureStore();
      // setup the router table with Induction selected as the initial component
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
                <Scene key="main" tabs={true} style={{backgroundColor: 'grey'}}>
                  <Scene key="home" component={Home} title="Tab #1" icon={TabIconBuilding} />
                  <Scene key="tab2" component={Enjoy} title="Tab #2" icon={TabIconMessage} />
                  <Scene key="tab3" component={Enjoy} title="Tab #3" icon={TabIconProfile} />
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
