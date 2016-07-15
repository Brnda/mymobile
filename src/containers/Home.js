import React, {
  Component,
  View,
  Text,
  StyleSheet,
  PropTypes
} from 'react-native'
import {Actions} from 'react-native-router-flux'

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
})

class Home extends Component {
  render() {
    return(
      <View style={styles.container}>
        <View>
          <Text style={styles.text}>Hi, {this.props.name}.</Text>
        </View>
        <View>
          <Text style={styles.back} onPress={()=> Actions.pop()}> Back </Text>
        </View>
      </View>
    )
  }
}

Home.propTypes = {
  name: PropTypes.string.isRequired
}

export default Home