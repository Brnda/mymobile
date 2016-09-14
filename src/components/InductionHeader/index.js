import React, {Component} from 'react';
import {
    View,
    Image,
    StyleSheet
} from 'react-native';
import styles from './styles';

class InductionHeader extends Component {
  constructor(props) {
    super();

    let computedStyle = {};
    if(props.style) {
      computedStyle = {...StyleSheet.flatten([styles.logo]), ...props.style}
    } else {
      computedStyle = styles.logo
    }
    this.state = {
      style: computedStyle
    };
  }

  render() {
    return (
        <View>
          <Image source={require('./img/logo_icon_only.png')}
                 style={this.state.style}/>
        </View>
    );
  }
}

export default InductionHeader;