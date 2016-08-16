import React, {Component} from 'react';
import {Text, View, StyleSheet} from 'react-native';
import Button from 'react-native-button';
import {Actions} from 'react-native-router-flux';

var styles = StyleSheet.create({
  container: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#272727'
  },
  label: {
    color: '#fff',
    fontSize: 19,
    fontWeight: 'bold'
  }
});

export default class GoogleSignup extends Component {
  render() {
    return <View style={styles.container}>
      <View>
        <View>
          <Text style={styles.label}> Google signup</Text>
        </View>
        <View>
          <Button onPress={Actions.home}>Next</Button>
        </View>
      </View>
    </View>
  }
}