'use strict';

import React, {Component} from 'react';
import {
  Text,
  TouchableHighlight
} from 'react-native';

class Home extends Component {
  onTouch(event) {
    // Actions.home({name: 'Mateo'})
    this.props.handleLogin('Mateo')
  }

  render() {
    return (
      <TouchableHighlight onPress={this.onTouch.bind(this)}>
        <Text>Send message</Text>
      </TouchableHighlight>
    )
  }
}

export default Home;