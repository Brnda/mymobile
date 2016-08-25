import React, { Component } from 'react';
import {
    View,
    Text,
    TouchableHighlight,
} from 'react-native';

import { Actions } from 'react-native-router-flux';

import styles from './styles';

class CodeInputSelector extends Component {
  _onChoose() {
    Actions.qrcodescreen({onSelect: this.props.onSelect});
  }

  render() {
    return (
        <View style={styles.choiceBoxes}>
          <TouchableHighlight onPress={this._onChoose.bind(this)}>
            <View style={styles.choiceBox}>
              <Text>QR Code</Text>
            </View>
          </TouchableHighlight>
          <View style={styles.choiceBox}>
            <Text>Invite Code</Text>
          </View>
        </View>
    )
  }
};

export default CodeInputSelector;