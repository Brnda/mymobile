import {
  View,
  Text,
  StyleSheet
} from 'react-native';
import React, {Component, PropTypes} from 'react';

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
  render() {
    return(
      <View style={styles.container}>
        <View>
          <Text style={styles.text}>Hi, {this.props.name}.</Text>
        </View>
      </View>
    )
  }
}

Home.propTypes = {
  name: PropTypes.string.isRequired
};

export default Home;