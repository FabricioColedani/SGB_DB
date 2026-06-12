/**
 * Helpers de validación para blindar endpoints POST/PUT.
 */

export const isNonEmptyString = (value) =>
  typeof value === 'string' && value.trim().length > 0;

export const parseNullableNumber = (value) => {
  if (value === undefined || value === null || value === '') return null;
  const number = Number(value);
  return Number.isNaN(number) ? null : number;
};

export const requireJsonContent = (req, res) => {
  if (!req.is('application/json')) {
    res.status(415).json({ error: 'Content-Type debe ser application/json' });
    return false;
  }
  return true;
};

/**
 * Valida que el body exista y contenga todos los campos obligatorios.
 * @returns {string[]|null} Lista de campos faltantes, o null si todo OK.
 */
export const getMissingRequiredFields = (body, requiredFields) => {
  const payload = body && typeof body === 'object' ? body : {};
  const missing = [];

  for (const field of requiredFields) {
    const value = payload[field];
    if (value === undefined || value === null) {
      missing.push(field);
    } else if (typeof value === 'string' && value.trim().length === 0) {
      missing.push(field);
    }
  }

  return missing.length > 0 ? missing : null;
};

export const respondMissingFields = (res, missingFields) =>
  res.status(400).json({
    error: 'Faltan datos obligatorios en el JSON',
    camposFaltantes: missingFields
  });

/**
 * Parsea un ID de ruta. Retorna null si el formato es inválido.
 */
export const parseRouteId = (idParam) => {
  const id = Number(idParam);
  if (!Number.isInteger(id) || id <= 0) return null;
  return id;
};

export const respondInvalidId = (res, resourceLabel = 'recurso') =>
  res.status(400).json({ error: `ID de ${resourceLabel} inválido` });

export const respondNotFound = (res, resourceLabel) =>
  res.status(404).json({ error: `${resourceLabel} no encontrado` });
