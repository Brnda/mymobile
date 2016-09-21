import React from 'react';
import {View, Text} from 'react-native';
import styles from './styles';
import HomeScreenTile from '../../components/HomeScreenTile'

export default Home = () => {
  return (
    <View style={styles.container}>
      <View style={styles.header}><Text>SPACES</Text></View>
      <View style={styles.row}>
        <HomeScreenTile text="MAIN ENTRANCE" containerStyle={{backgroundColor: '#ff0'}} />
        <HomeScreenTile text="MY FLOOR" containerStyle={{backgroundColor: '#0f0'}} />
      </View>
      <View style={styles.row}>
        <HomeScreenTile text="LAUNDRY" containerStyle={{backgroundColor: '#ff0'}} />
        <HomeScreenTile text="GYM" containerStyle={{backgroundColor: '#0f0'}} />
      </View>
      <View style={styles.row}>
        <HomeScreenTile
          text="POOL"
          containerStyle={{backgroundColor: '#ff0'}}
          statusText="Status Unavailable"
          statusTextStyle={{color: '#ccc'}} />
        <HomeScreenTile text="GARAGE" containerStyle={{backgroundColor: '#0f0'}} />
      </View>
    </View>
  );
}