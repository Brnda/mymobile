import React, {Component} from 'react';
import {
    View,
    Image,
    StyleSheet
} from 'react-native';
import styles from './styles';

class InductionHeader extends Component {
  render() {
    return (
        <View>
          <Image source={require('./img/logo_icon_only.png')}
                 style={[styles.logo, this.props.style]}/>
        </View>
    );
  }
}

export default InductionHeader;