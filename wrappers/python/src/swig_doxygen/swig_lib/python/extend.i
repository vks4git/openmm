%extend OpenMM::Context {
  PyObject *getStateAsLists(int getPositions=0,
                            int getVelocities=0,
                            int getForces=0,
                            int getEnergy=0,
                            int getParameters=0) {
    int types;
    double simTime;
    PyObject *pPeriodicBoxVectorsList;
    PyObject *pEnergy;
    PyObject *pPositions;
    PyObject *pVelocities;
    PyObject *pForces;
    PyObject *pyTuple;
    PyObject *pParameters;

    types = State::Energy;
    if (getPositions) types |= State::Positions;
    if (getVelocities) types |= State::Velocities;
    if (getForces) types |= State::Forces;
    if (getEnergy) types |= State::Energy;
    if (getParameters) types |= State::Parameters;
    State state = self->getState(types);

    simTime=state.getTime();

    OpenMM::Vec3 myVecA;
    OpenMM::Vec3 myVecB;
    OpenMM::Vec3 myVecC;
    state.getPeriodicBoxVectors(myVecA, myVecB, myVecC);
    pPeriodicBoxVectorsList = Py_BuildValue("(d,d,d),(d,d,d), (d,d,d)",
                                            myVecA[0], myVecA[1], myVecA[2],
                                            myVecB[0], myVecB[1], myVecB[2],
                                            myVecC[0], myVecC[1], myVecC[2]);

    if (getPositions) {
      pPositions = copyVVec3ToList(state.getPositions());
    } else {
      pPositions = Py_None;
      Py_INCREF(Py_None);
    }
    if (getVelocities) {
      pVelocities = copyVVec3ToList(state.getVelocities());
    } else {
      pVelocities = Py_None;
      Py_INCREF(Py_None);
    }
    if (getForces) {
      pForces = copyVVec3ToList(state.getForces());
    } else {
      pForces = Py_None;
      Py_INCREF(Py_None);
    }
    if (getEnergy) {
      pEnergy = Py_BuildValue("(d,d)",
                             state.getKineticEnergy(),
                             state.getPotentialEnergy());
    } else {
      pEnergy = Py_None;
      Py_INCREF(Py_None);
    }
    if (getParameters) {
      pParameters = Py_None;
      Py_INCREF(Py_None);
    } else {
      pParameters = Py_None;
      Py_INCREF(Py_None);
    }
  
    pyTuple=Py_BuildValue("(d,N,N,N,N,N,N)",
                          simTime, pPeriodicBoxVectorsList, pEnergy,
                          pPositions, pVelocities,
                          pForces, pParameters);
  
    return pyTuple;
  }


  %pythoncode {
    def getState(self,
                 getPositions=False,
                 getVelocities=False,
                 getForces=False,
                 getEnergy=False,
                 getParameters=False):
        """
        getState(self,
                 getPositions = False,
                 getVelocities = False,
                 getForces = False,
                 getEnergy=False,
                 getParameters=False)
              -> State
        """
        
        if getPositions: getP=1
        else: getP=0
        if getVelocities: getV=1
        else: getV=0
        if getForces: getF=1
        else: getF=0
        if getEnergy: getE=1
        else: getE=0
        if getParameters: getPa=1
        else: getPa=0

        (simTime, periodicBoxVectorsList, energy, coordList, velList,
         forceList, paramMap) = \
            self.getStateAsLists(getP, getV, getF, getE, getPa)
        
        state = State(simTime=simTime,
                      energy=energy,
                      coordList=coordList,
                      velList=velList,
                      forceList=forceList,
                      periodicBoxVectorsList=periodicBoxVectorsList,
                      paramMap=paramMap)
        return state
  }

}


%extend OpenMM::NonbondedForce {
  %pythoncode {
    def addParticle_usingRVdw(self, charge, rVDW, epsilon):
        """Add particle using elemetrary charge.  Rvdw and epsilon,
           which is consistent with AMBER parameter file usage.
           Note that the sum of the radii of the two interacting atoms is
           the minimum energy point in the Lennard Jones potential and
           is often called rMin.  The conversion from sigma follows:
           rVDW = 2^1/6 * sigma/2
        """
        return self.addParticle(charge, rVDW/RVDW_PER_SIGMA, epsilon)

    def addException_usingRMin(self, particle1, particle2,
                               chargeProd, rMin, epsilon):
        """Add interaction exception using the product of the two atoms'
           elementary charges, rMin and epsilon, which is standard for AMBER
           force fields.  Note that rMin is the minimum energy point in the
           Lennard Jones potential.  The conversion from sigma is:
           rMin = 2^1/6 * sigma.
        """
        return self.addException(particle1, particle2,
                                 chargeProd, rMin/RMIN_PER_SIGMA, epsilon)
  }
}


%extend OpenMM::System {
  %pythoncode {
    def __getstate__(self):
        serializationString = XmlSerializer.serializeSystem(self)
        return serializationString

    def __setstate__(self, serializationString):
        system = XmlSerializer.deserializeSystem(serializationString)
        self.this = system.this
  }
}
