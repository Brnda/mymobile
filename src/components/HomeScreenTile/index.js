import React, {Component} from 'react';
import styles from './styles';
import {
  StyleSheet,
  View,
  Text,
  StatusBar,
  TouchableOpacity,
  Image
} from 'react-native';
import * as Progress from 'react-native-progress';

class HomeScreenTile extends Component {

  _onSelect() {
    this.props.onSelect(this.props.spaceId);
  }

  render() {
    let spacerHeight = 50;
    if (((this.props.statusBarTotal && this.props.statusBarTotal > 0) || this.props.fetching)) {
      spacerHeight = 22;
    }
    return (
      <TouchableOpacity style={[styles.container, this.props.containerStyle]} onPress={this._onSelect.bind(this)}>
        {this.props.iconName &&
          <Image source={this.props.icon} style={styles.icon}/>
        }
        <View style={styles.textView}>
          <Text style={styles.text}>{this.props.text}</Text>
        </View>

        {((this.props.statusBarTotal && this.props.statusBarTotal > 0) || this.props.fetching) &&
          <View>
            <View style={{height: 10}} />
            <Progress.Bar
              progress={(this.props.statusBarFilled / this.props.statusBarTotal)}
              width={120}
              indeterminate={this.props.fetching}
              style={styles.progressbar}
              color={this.props.statusColor}
            />
            <View style={{height: 10}} />
          </View>
        }
        {this.props.statusText &&
        <View style={styles.statusTextView}>
          <Text style={[styles.statusText, this.props.statusTextStyle]}>{this.props.statusText}</Text>
        </View>
        }
        <View style={{height: spacerHeight}} />
        <View style={styles.divider} />
      </TouchableOpacity>
    )
  }
}

export default HomeScreenTile;
