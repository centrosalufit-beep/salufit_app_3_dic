// Inspecciona Excels candidatos a importar como citas
const XLSX = require(require('path').join(__dirname, '..', 'functions', 'node_modules', 'xlsx'));
const path = require('path');

const HOME = process.env.HOME || process.env.USERPROFILE;
const DOWNLOADS = path.join(HOME, 'Downloads');

const files = [
  'informe_citas_equipo_2026_04_30.xlsx',
  'informe_citas_equipo_2026_04_17.xlsx',
  'citas.xlsx',
];

for (const fname of files) {
  const fullPath = path.join(DOWNLOADS, fname);
  console.log('\n' + '='.repeat(80));
  console.log('📄 ' + fname);
  console.log('='.repeat(80));
  let wb;
  try {
    wb = XLSX.readFile(fullPath);
  } catch (e) {
    console.log('❌ Error leyendo:', e.message);
    continue;
  }
  for (const sheetName of wb.SheetNames) {
    const sheet = wb.Sheets[sheetName];
    const rows = XLSX.utils.sheet_to_json(sheet, { defval: '', raw: false });
    console.log('\n  📋 Hoja: "' + sheetName + '"');
    console.log('     Filas: ' + rows.length);
    if (rows.length > 0) {
      console.log('     Columnas: ' + Object.keys(rows[0]).join(' | '));
      console.log('     Primeras 2 filas:');
      rows.slice(0, 2).forEach((r, i) => {
        console.log('       [' + (i+1) + '] ' + JSON.stringify(r).slice(0, 400));
      });
      // Mirar rango de fechas (si existe Fecha)
      const fechas = rows.map(r => r['Fecha'] || r['Fecha cita']).filter(Boolean);
      if (fechas.length) {
        console.log('     Rango fechas: ' + fechas[0] + ' → ' + fechas[fechas.length - 1]);
      }
    }
  }
}
