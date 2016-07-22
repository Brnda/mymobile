'use strict';

import React from 'react';
import { expect } from 'chai';
import { shallow } from 'enzyme';
import { Text } from 'react-native';

const Home = require.requireActual('../TestView').default;

describe("<TestView />", () => {
  it("should contain the welcome text", () => {
    const homeComponent = shallow(<Home />);

    expect(homeComponent
      .find(Text)
      .first()
      .props()
      .children
    ).to.equal("Send message");
  });
});