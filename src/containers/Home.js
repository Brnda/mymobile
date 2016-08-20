import {
    View,
    Text,
    StyleSheet,
    TouchableOpacity
} from 'react-native';
import React, {Component, PropTypes} from 'react';
import {Actions} from 'react-native-router-flux';
import QRCodeScreen from '../components/QRCodeScreen'

var styles = StyleSheet.create({
    container: {
        flex: 1,
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'center',
        backgroundColor: '#272727'
    },
    text: {
        fontFamily: 'Lato-Regular',
        fontSize: 18,
        color: '#fff'
    },
    back: {
        fontFamily: 'Lato-Regular',
        fontSize: 12,
        color: '#fff'
    }
});

class Home extends Component {
    _onPressQRCode() {
        Actions.qrcodescreen({onSuccess: Home._onSuccess});
    }

    static _onSuccess(result) {
        console.log('I got this far '+ result);
    }

    render() {
        return (
            <View style={styles.container}>
                <View>
                    <TouchableOpacity onPress={this._onPressQRCode}>
                        <Text>Read QRCode</Text>
                    </TouchableOpacity>
                </View>
            </View>
        )
    }
}

export default Home;