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

  _selectStatusText(percentage) {
    if(percentage >= 0 && percentage <= 0.25) {
      return {text: 'EMPTY', color: '#39a851'};
    }

    if(percentage > 0.25 && percentage <= 0.50) {
      return {text: 'SOMEWHAT EMPTY', color: '#8cce1f'};
    }

    if(percentage > 0.50 && percentage <= 0.75) {
      return {text: 'GETTING FULL', color: '#edba00'};
    }

    if(percentage > 0.75 && percentage <= 1) {
      return {text: 'FULL', color: '#df0a0a'};
    }

    return {text: 'NO DATA', color: 'black'};
  }

  render() {
    const percentage = this.props.statusBarFilled / this.props.statusBarTotal;
    return (
      <TouchableOpacity style={styles.container}
          onPress={this._onSelect.bind(this)}>
        <Image source={this.props.icon} style={styles.icon}/>
        <Text>{this.props.text}</Text>
        {(this.props.statusBarTotal > 0) &&
          <View style={{alignItems: 'center'}}>
            <Progress.Bar
              style={styles.progressBar}
              progress={percentage}
              width={120}
              indeterminate={!this.props.enabled}
              color={this._selectStatusText(percentage)['color']}/>

            <Text style={styles.statusText}>{this._selectStatusText(percentage).text}</Text>
          </View>
        }
      </TouchableOpacity>
    )
  }
}

export default HomeScreenTile;
