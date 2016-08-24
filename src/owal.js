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
import {
    Provider,
    connect
} from 'react-redux';
import configureStore from './lib/configureStore';
import App from './containers/App/index';
import Home from './containers/Home';
import QRCodeScreen from './components/QRCodeScreen';

/**
 * ## Native entry point.
 */

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
                            <Scene key="home"
                                   component={Home}/>
                            <Scene key="qrcodescreen"
                                   component={QRCodeScreen}/>
                        </Scene>
                    </Router>
                </Provider>
            )
        }
    })
    /**
     * registerComponent to the AppRegistery and off we go....
     */

    AppRegistry.registerComponent('owalMobile', () => Owal)
}
