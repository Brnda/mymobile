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

// SILLY REACT!
// WNF-WAI https://github.com/facebook/react-native/issues/2481
// Workaround #2 from http://stackoverflow.com/questions/33907218/react-native-use-variable-for-image-file
const icons = {
  buildingentrance: require('./../../icons/buildingentrance.png'),
  garage: require('./../../icons/garage.png'),
  gym: require('./../../icons/gym.png'),
  laundry: require('./../../icons/laundry.png'),
  myfloor: require('./../../icons/myfloor.png'),
  pool: require('./../../icons/pool.png')
};

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
        <Image source={icons[this.props.iconName]}
               style={styles.icon}/>
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
