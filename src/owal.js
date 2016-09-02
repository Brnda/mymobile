import React from 'react';
import {
    AppRegistry,
    Navigator,
    View,
    Text
} from 'react-native';
import {
    Router,
    Scene
} from 'react-native-router-flux';
import {Provider} from 'react-redux';
import configureStore from './lib/configureStore';
import App from './containers/App/index';
import TenantReview from './containers/TenantReview';
import QRCodeScreen from './components/QRCodeScreen';
import TenantReviewLastQuestion from './components/TenantReviewLastQuestion';
import TextInviteCodeScreen from './components/TextInviteCodeScreen';

export default function native(platform) {

    let Owal = React.createClass({
        render() {
            const store = configureStore()
            // setup the router table with App selected as the initial component
            return (
                <Provider store={store}>
                    <Router hideNavBar={true}>
                        <Scene key="root">
                            <Scene key="app"
                                   component={App}
                                   title="App"
                                   initial={true}/>
                            <Scene key="tenatReview"
                                   component={TenantReview}/>
                            <Scene key="lastTenantQuestion"
                                   component={TenantReviewLastQuestion}/>
                            <Scene key="qrcodescreen"
                                   component={QRCodeScreen}/>
                            <Scene key="textinvitecodescreen"
                                   component={TextInviteCodeScreen}/>
                        </Scene>
                    </Router>
                </Provider>
            )
        }
    });

    AppRegistry.registerComponent('owalMobile', () => Owal)
}
