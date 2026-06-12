import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import {
  getMissingRequiredFields,
  parseRouteId,
  isNonEmptyString
} from '../src/middleware/validation.js';

describe('validation middleware', () => {
  it('detecta campos obligatorios faltantes', () => {
    assert.deepEqual(getMissingRequiredFields({}, ['nombre', 'apellido']), ['nombre', 'apellido']);
    assert.deepEqual(getMissingRequiredFields({ nombre: 'Juan' }, ['nombre', 'apellido']), ['apellido']);
    assert.deepEqual(getMissingRequiredFields({ nombre: '   ' }, ['nombre']), ['nombre']);
    assert.equal(getMissingRequiredFields({ nombre: 'Juan', apellido: 'Pérez' }, ['nombre', 'apellido']), null);
  });

  it('valida IDs de ruta', () => {
    assert.equal(parseRouteId('1'), 1);
    assert.equal(parseRouteId('abc'), null);
    assert.equal(parseRouteId('0'), null);
    assert.equal(parseRouteId('-5'), null);
  });

  it('valida strings no vacíos', () => {
    assert.equal(isNonEmptyString('Fabri'), true);
    assert.equal(isNonEmptyString('  '), false);
    assert.equal(isNonEmptyString(null), false);
  });
});
