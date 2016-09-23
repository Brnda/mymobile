import React, {Component} from 'react';
import styles from './styles';
import {
  StyleSheet,
  View,
  Text,
  StatusBar,
  TouchableOpacity
} from 'react-native';

class HomeScreenTile extends Component {

  _onSelect() {
    console.log("Selected spaceId: " + this.props.spaceId);
    this.props.onSelect(this.props.spaceId);
  }

  render() {
    console.log("rendering SpaceID: " + this.props.spaceId);
    return (
      <TouchableOpacity style={[styles.container, this.props.containerStyle]} onPress={this._onSelect.bind(this)}>
        {this.props.imageName &&
        <Image source={require('./img/' + this.props.imageName + '.png')}
               style={[styles.logo, this.props.imageStyle]}/>
        }
        <View style={styles.textView}>
          <Text style={styles.text}>{this.props.text}</Text>
        </View>
        {this.props.statusText &&
        <View style={styles.statusTextView}>
          <Text style={[styles.statusText, this.props.statusTextStyle]}>{this.props.statusText}</Text>
        </View>
        }
      </TouchableOpacity>
    )
  }
}

export default HomeScreenTile;
