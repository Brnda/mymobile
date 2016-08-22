import React, {Component} from 'react';
import {View, Text, StyleSheet} from 'react-native';
import Button from 'react-native-button';
import {Actions} from 'react-native-router-flux';

var styles = StyleSheet.create({
  container: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#272727'
  }
});

export default class FacebookSignup extends Component {
  render() {
    return <View style={styles.container}>
      <View>

        <View>
          <Button onPress={()=>Actions.home({name: 'Mateo'})}>Next</Button>
        </View>
      </View>
    </View>
  }
}