import React, {Component} from 'react';
import {connect} from 'react-redux';
import {bindActionCreators} from 'redux';
import {Actions} from 'react-native-router-flux';
import {
    StyleSheet,
    View,
    Text,
    Image,
    Switch,
    TouchableOpacity,
    StatusBar
} from 'react-native';
import styles from './styles';
import * as InductionState from '../../reducers/induction/inductionReducer';
import InductionHeader from '../../components/InductionHeader';

class TenantReviewLastQuestion extends Component {
  _onPressContinueButton() {
    Actions.home();
  }

  render() {
    return (
        <View style={styles.container}>
          <StatusBar hidden={true} />
          <InductionHeader/>
          <View style={styles.header}>
            <Text style={styles.headerText}>One more question</Text>
          </View>
          <View style={styles.tenantDetails}>
            <View style={styles.tenantDetailsRow}>
              <View style={styles.tenantDetailColumnLeft}>
                <Text style={styles.tenantDetailText}>Would you like to use your name in the building directory?</Text>
              </View>
              <View style={styles.tenantDetailColumnRight}>
                <Switch onTintColor="#fff" tintColor="#000" thumbTintColor="#000" value={this.props.include}
                        onValueChange={(value) => this.props.actions.includeInDirectory()}/>
              </View>
            </View>
          </View>
          <TouchableOpacity style={styles.continueButton} onPress={this._onPressContinueButton}>
            <Text style={styles.continueButtonText}>START USING OWAL!</Text>
          </TouchableOpacity>
        </View>
    )
  }
}

const mapStateToProps = (state) => {
  return {
    include: state.induction.get('INCLUDE_DIR')
  }
};

function mapDispatchToProps(dispatch) {
  return {
    actions: bindActionCreators({...InductionState}, dispatch),
    dispatch
  }
}

export default connect(mapStateToProps, mapDispatchToProps)(TenantReviewLastQuestion);

