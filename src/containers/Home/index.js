import React from 'react';
import {View, Text} from 'react-native';
import styles from './styles';

export default Home = () => {
  return (
      <View style={styles.container}>
        <View style={{backgroundColor: 'yellow', alignItems: 'center', marginTop: 50}}><Text>SPACES</Text></View>
        <View style={{backgroundColor: 'red', margin: 10, flexDirection: 'row', flex: 1}}>
          <View style={{backgroundColor: 'blue', flex: 1, margin: 20, alignItems: 'center'}}><Text>MAIN ENTRANCE</Text></View>
          <View style={{backgroundColor: 'green', flex: 1, margin: 20, alignItems: 'center'}}><Text>MY FLOOR</Text></View>
        </View>
        <View style={{backgroundColor: 'red', margin: 10, flexDirection: 'row', flex: 1}}>
          <View style={{backgroundColor: 'blue', flex: 1, margin: 20, alignItems: 'center'}}><Text>LAUNDRY</Text></View>
          <View style={{backgroundColor: 'green', flex: 1, margin: 20, alignItems: 'center'}}><Text>GYM</Text></View>
        </View>
        <View style={{backgroundColor: 'red', margin: 10, flexDirection: 'row', flex: 1}}>
          <View style={{backgroundColor: 'blue', flex: 1, margin: 20, alignItems: 'center'}}><Text>POOL</Text></View>
          <View style={{backgroundColor: 'green', flex: 1, margin: 20, alignItems: 'center'}}><Text>GARAGE</Text></View>
        </View>
      </View>
  );
}