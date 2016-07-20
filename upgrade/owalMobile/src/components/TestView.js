import React, {Component} from 'react'
import { View, Text, TouchableHighlight} from 'react-native'
import {Actions} from 'react-native-router-flux'
// import {t} from 'tcomb-form-native'

// const Form = t.form.Form
//
// const Person = t.struct({
//   name: t.String,              // a required string
//   surname: t.maybe(t.String)  // an optional string
// });


class TestView extends Component {
  onTouch(event) {
    // Actions.home({name: 'Mateo'})
    this.props.handleLogin('Mateo')
  }
  render() {
    return(
      <View>
        <TouchableHighlight onPress={this.onTouch.bind(this)}>
          <Text>Send message</Text>
        </TouchableHighlight>
      </View>
    )
  }
}

export default TestView