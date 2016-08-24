'use strict';

var React = require('react');

import {
    StyleSheet,
    View,
    Text,
    TouchableOpacity,
    VibrationIOS,
} from 'react-native';

import {Actions} from 'react-native-router-flux';
import Camera from 'react-native-camera';

var QRCodeScreen = React.createClass({

    propTypes: {
        cancelButtonVisible: React.PropTypes.bool,
        cancelButtonTitle: React.PropTypes.string,
        // onSuccess: React.PropTypes.func.isrequired,
        // onCancel: React.PropTypes.func,
    },

    getDefaultProps: function() {
        return {
            cancelButtonVisible: false,
            cancelButtonTitle: 'Cancel',
        };
    },

    _onPressCancel: function() {
        var $this = this;
        requestAnimationFrame(function() {
            $this.props.navigator.pop();
            if ($this.props.onCancel) {
                $this.props.onCancel();
            }
        });
    },

    _onBarCodeRead: function(result) {
        var $this = this;

        if (this.barCodeFlag) {
            this.barCodeFlag = false;

            setTimeout(function() {
                VibrationIOS.vibrate();
                //console.log('props '+$this.props.text);
                $this.props.onSuccess(result.data);
                Actions.pop();
            }, 1000);
        }
    },

    render: function() {
        var cancelButton = null;
        this.barCodeFlag = true;

        if (this.props.cancelButtonVisible) {
            cancelButton = <CancelButton onPress={this._onPressCancel} title={this.props.cancelButtonTitle} />;
        }

        return (
            <Camera onBarCodeRead={this._onBarCodeRead} style={styles.camera}>
                <View style={styles.rectangleContainer}>
                    <View style={styles.rectangle}/>
                </View>
                {cancelButton}
            </Camera>
        );
    },
});

var CancelButton = React.createClass({
    render: function() {
        return (
            <View style={styles.cancelButton}>
                <TouchableOpacity onPress={this.props.onPress}>
                    <Text style={styles.cancelButtonText}>{this.props.title}</Text>
                </TouchableOpacity>
            </View>
        );
    },
});

var styles = StyleSheet.create({
    camera: {
        height: 568,
        alignItems: 'center',
    },

    rectangleContainer: {
        flex: 1,
        alignItems: 'center',
        justifyContent: 'center',
        backgroundColor: 'transparent',
    },

    rectangle: {
        height: 250,
        width: 250,
        borderWidth: 2,
        borderColor: '#00FF00',
        backgroundColor: 'transparent',
    },

    cancelButton: {
        flexDirection: 'row',
        justifyContent: 'center',
        backgroundColor: 'white',
        borderRadius: 3,
        padding: 15,
        width: 100,
        bottom: 10,
    },
    cancelButtonText: {
        fontSize: 17,
        fontWeight: '500',
        color: '#0097CE',
    }
});

export default QRCodeScreen;