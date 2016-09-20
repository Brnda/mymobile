import React, {PropTypes} from 'react';
import styles from './styles';
import {
  StyleSheet,
  View,
  Text,
  StatusBar
} from 'react-native';

class Enjoy extends Component {
  render() {
    return (
      <View style={styles.container}>
        {this.props.imageName &&
          <Image source={require('./img/' + this.props.imageName + '.png')}
                                        style={[styles.logo, this.props.imageStyle]}/>
        }
        <View style={styles.textView}>
          <Text style={styles.text}>{this.props.text}</Text>
        </View>
        {this.props.statusText &&
          <View style={styles.statusTextView}>
            <Text style={[style.statusText, this.props.statusTextStyle]}>{this.props.statusText}</Text>
          </View>
        }
      </View>
    )
  }
}