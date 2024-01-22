/* To learn more about this file see: https://angular.io/config/tsconfig. */
{
  "extends": "../tsconfig.json",
  "compilerOptions": {
    "baseUrl": "./",
    "outDir": "./out-tsc/lib",
    "declaration": true,
    "declarationMap": true,
    "inlineSources": true,
    "types": [],
    "strictPropertyInitialization": false,
    "typeRoots": ["../node_modules/@types", "./typings.d.ts"]
  },
  "exclude": [
    "src/test.ts",
    "**/*.spec.ts"
  ]
}
